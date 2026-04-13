import os
import pandas as pd
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

class ClinicalTrialDataAgent:
    def __init__(self):
        load_dotenv()

        BASE_DIR = os.path.dirname(os.path.abspath(__file__))
        file_path = os.path.join(BASE_DIR, "adae.csv")

        print("DEBUG PATH:", file_path)  # optional

        self.df = pd.read_csv(file_path)[
            ["USUBJID", "AETERM", "AESEV", "AESOC"]
        ]

        # Schema Definition (for LLM)
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
        "Example output format:\n"
        "{{\"target_column\": \"AESEV\", \"filter_value\": \"SEVERE\"}}\n\n"
        "Rules:\n"
        "- severity → AESEV\n"
        "- symptom → AETERM\n"
        "- body system → AESOC\n\n"
        "Question: {question}"
    )
])

        self.chain = self.prompt | self.llm

    # Parse Question (LLM)
    def parse_question(self, question):
        try:
            response = self.chain.invoke({"question": question})
            return json.loads(response.content)

        except Exception as e:
            raise ValueError(f"LLM parsing failed: {e}")

    # Execute Query (Pandas)
    def run_query(self, parsed):
        try:
            col = parsed["target_column"]
            val = parsed["filter_value"]

            filtered = self.df[
                self.df[col].astype(str).str.contains(val, case=False, na=False)
            ]

            subjects = filtered["USUBJID"].unique()

            return {
                "unique_subject_count": len(subjects),
                "subject_ids": list(subjects),
                "matching_events": filtered.to_dict(orient="records")
            }

        except KeyError as e:
            raise ValueError(f"Invalid column from LLM: {e}")

    # Entry Point
    def ask(self, question):
        parsed = self.parse_question(question)
        return self.run_query(parsed)
