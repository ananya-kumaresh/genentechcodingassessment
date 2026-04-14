import os
import json
import re
import pandas as pd
from dotenv import load_dotenv

from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate


class ClinicalTrialDataAgent:
    """
    Clinical AI Agent that maps natural language questions
    to structured Pandas queries using an LLM.
    """

    def __init__(self, file_path="adae.csv"):
        # Load Env
        load_dotenv()

        # -----------------------------
        # FILE PATH 
        # -----------------------------
        BASE_DIR = os.path.dirname(os.path.abspath(__file__))

        possible_paths = [
            os.path.join(BASE_DIR, file_path),               
            os.path.join(BASE_DIR, "adae.csv"),              
            "Question4_Python/adae.csv"                     
        ]

        for path in possible_paths:
            if os.path.exists(path):
                file_path = path
                break
        else:
            raise FileNotFoundError("adae.csv not found in any expected location")

        # Load Data
        self.df = pd.read_csv(file_path)[
            ["USUBJID", "AETERM", "AESEV", "AESOC"]
        ]

        # Schema Definition
        self.schema = {
            "AESEV": "Severity (mild, moderate, severe)",
            "AETERM": "Adverse event term (e.g., headache, nausea)",
            "AESOC": "Body system (e.g., cardiac, skin, nervous)"
        }

        # LLM Setup
        self.llm = ChatOpenAI(
            model="gpt-4o-mini",
            temperature=0
        )

        # Prompt
        self.prompt = ChatPromptTemplate.from_messages([
            (
                "system",
                "You are a clinical trial data assistant.\n"
                "Map user questions to dataset columns.\n\n"
                "Schema:\n"
                "AESEV = severity (mild, moderate, severe)\n"
                "AETERM = adverse event term (e.g., headache, nausea)\n"
                "AESOC = body system (e.g., cardiac, skin, nervous)\n"
            ),
            (
                "human",
                "Return ONLY JSON.\n\n"
                "Example:\n"
                "{{\"target_column\": \"AESEV\", \"filter_value\": \"SEVERE\"}}\n\n"
                "Rules:\n"
                "- severity → AESEV\n"
                "- symptom → AETERM\n"
                "- body system → AESOC\n\n"
                "Question: {question}"
            )
        ])

        self.chain = self.prompt | self.llm

    # -----------------------------
    # Parse Question
    # -----------------------------
    def parse_question(self, question):
        response = self.chain.invoke({"question": question})
        content = response.content.strip()

        content = content.replace("```json", "").replace("```", "")

        try:
            return json.loads(content)

        except Exception:
            match = re.search(r"\{.*\}", content, re.DOTALL)
            if match:
                return json.loads(match.group())

            raise ValueError(f"LLM parsing failed: {content}")

    # -----------------------------
    # Execute Query
    # -----------------------------
    def run_query(self, parsed):
        try:
            col = parsed["target_column"]
            val = parsed["filter_value"]

            df = self.df.copy()

            df[col] = df[col].astype(str).str.upper()
            val = str(val).upper()

            filtered = df[df[col].str.contains(val, na=False)]

            subjects = filtered["USUBJID"].unique()

            return {
                "unique_subject_count": len(subjects),
                "subject_ids": list(subjects),
                "matching_events": filtered.to_dict(orient="records")
            }

        except KeyError as e:
            raise ValueError(f"Invalid column from LLM: {e}")

    # -----------------------------
    # Entry Point
    # -----------------------------
    def ask(self, question):
        parsed = self.parse_question(question)
        return self.run_query(parsed)
