from datetime import datetime, timezone
from typing import List, Dict, Any, Optional
from openai import AsyncOpenAI
import logging
import json
import os

from repositories.postgres_repository import PostgresDB
from models.analysis_response import AnalysisResponse

logger = logging.getLogger("journal")

class EntryService:
    def __init__(self, db: PostgresDB):
        self.db = db
        logger.debug("EntryService initialized with PostgresDB client.")

    async def create_entry(self, entry_data: Dict[str, Any]) -> Dict[str, Any]:
        """Creates a new entry."""
        logger.info("Creating entry")
        now = datetime.now(timezone.utc)
        entry = {
            **entry_data,
            "created_at": now,
            "updated_at": now
        }
        logger.debug("Entry created: %s", entry)
        return await self.db.create_entry(entry)

    async def get_all_entries(self) -> List[Dict[str, Any]]:
        """Gets all entries."""
        logger.info("Fetching all entries")
        entries = await self.db.get_all_entries()
        logger.debug("Fetched %d entries", len(entries))
        return entries

    async def get_entry(self, entry_id: str) -> Dict[str, Any]:
        """Gets a specific entry."""
        logger.info("Fetching entry %s", entry_id)
        entry = await self.db.get_entry(entry_id)
        if entry:
            logger.debug("Entry %s found", entry_id)
        else:
            logger.warning("Entry %s not found", entry_id)
        return entry

    async def update_entry(self, entry_id: str, updated_data: Dict[str, Any]) -> Dict[str, Any]:
        """Updates an existing entry."""
        logger.info("Updating entry %s", entry_id)
        existing_entry = await self.db.get_entry(entry_id)
        if not existing_entry:
            logger.warning("Entry %s not found. Update aborted.", entry_id)
            return None

        updated_data = {
            **updated_data,
            "id": entry_id,
            "updated_at": datetime.now(timezone.utc),
            "created_at": existing_entry.get("created_at")
        }
        await self.db.update_entry(entry_id, updated_data)
        logger.debug("Entry %s updated", entry_id)
        return updated_data

    async def delete_entry(self, entry_id: str) -> None:
        """Deletes a specific entry."""
        logger.info("Deleting entry %s", entry_id)
        await self.db.delete_entry(entry_id)
        logger.debug("Entry %s deleted", entry_id)

    async def delete_all_entries(self) -> None:
        """Deletes all entries."""
        logger.info("Deleting all entries")
        await self.db.delete_all_entries()
        logger.debug("All entries deleted")

    async def analyze_entry(self, entry_id: str) -> AnalysisResponse | None:
        """Analyzes a journal entry using OpenAI's API."""
        logger.info("Analyzing entry %s", entry_id)
        
        # Fetch the entry
        entry = await self.get_entry(entry_id)
        if not entry:
            logger.warning("Entry %s not found. Analysis aborted.", entry_id)
            return None
        
        # Combine the three fields into one string for LLM analysis
        entry_text = f"Work: {entry['work']}\n\nStruggle: {entry['struggle']}\n\nIntention: {entry['intention']}"
        logger.debug("Combined entry text: %s", entry_text)
        
        openai_client = AsyncOpenAI(
            api_key=os.getenv("AZURE_OPENAI_API_KEY"),
            base_url=os.getenv("AZURE_OPENAI_BASE_URL")
        )

        system_message = (
            "You are an experienced learning coach analyzing student learning journals. "
            "Analyze this journal entry and provide a response following this JSON format: "
            '{"sentiment": "positive" | "negative" | "neutral", '
            '"summary": "2 sentence summary", '
            '"topics": ["topic1", "topic2"], '
            '"struggle_detected": "true" | "false"} '
            "Rules: Ensure the summary captures key learnings and/or challenges. "
            "Limit topics to 1-3 key topics. Be objective. "
            "Do not make assumptions beyond what is written."
        )

        user_message = f"Journal Entry:\n{entry_text}"

        response = await openai_client.chat.completions.create(
            model="gpt4omini",
            messages=[
                {"role": "system", "content": system_message},
                {"role": "user", "content": user_message}
            ],
            response_format={
                "type": "json_schema",
                "json_schema": {
                    "name": "AnalysisResponse",
                    "schema": AnalysisResponse.model_json_schema(),
                    "strict": True
                }
            },
            max_tokens=1000,
            temperature=0.7,
        )

        # Extract the response content and parse it as AnalysisResponse
        content = response.choices[0].message.content
        if not content:
            logger.error("Empty response from LLM")
            raise ValueError("LLM returned empty response")
        
        analysis_json = json.loads(content)
        analysis_result = AnalysisResponse(**analysis_json)
        logger.debug("Parsed analysis result: %s", analysis_result)

        return analysis_result