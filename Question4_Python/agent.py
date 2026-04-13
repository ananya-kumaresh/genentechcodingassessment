import os
import json
import re
import pandas as pd
from dotenv import load_dotenv

from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate


class ClinicalTrialDataAgent:
    def __init__(self):
        load_dotenv()

        # -----------------------------
        # SAFE FILE PATH (DEPLOYMENT FIX)
        # -----------------------------
        BASE_DIR = os.path.dirname(os.path.abspath(__file__))
        file_path = os.path.join(BASE_DIR, "adae.csv")

        self.df = pd.read_csv(file_path)[
            ["USUBJID", "AETERM", "AESEV", "AESOC"]
        ]

        # -----------------------------
        # LLM
        # -----------------------------
        self.llm = ChatOpenAI(
            model="gpt-4o-mini",
            temperature=0
        )

        # -----------------------------
        # PROMPT (STRICT JSON OUTPUT)
        # -----------------------------
        self.prompt = ChatPromptTemplate.from_messages([
            ("system",
             "You are a clinical trial assistant. "
             "Return ONLY valid JSON. No explanation. No markdown."),

            ("human",
             """
Map the question into JSON format:

{{
  "target_column": "AESEV",
  "filter_value": "SEVERE"
}}

Rules:
- severity / intensity → AESEV
- symptom / condition → AETERM
- body system → AESOC

Question: {question}
""")
        ])

        self.chain = self.prompt | self.llm

    # -----------------------------
    # PARSER
    # -----------------------------
    def parse_question(self, question):
        response = self.chain.invoke({"question": question})
        content = response.content.strip()

        # remove markdown if any
        content = content.replace("```json", "").replace("```", "")

        try:
            return json.loads(content)

        except Exception:
            match = re.search(r"\{.*\}", content, re.DOTALL)
            if match:
                return json.loads(match.group())

            raise ValueError(f"LLM returned invalid JSON: {content}")

    # -----------------------------
    # QUERY ENGINE
    # -----------------------------
    def run_query(self, parsed):
    col = parsed["target_column"]
    val = parsed["filter_value"]

    df = self.df.copy()

    # normalize safely
    df[col] = df[col].astype(str).str.upper()
    val = str(val).upper()

    filtered = df[df[col].str.contains(val, na=False)]

    subjects = filtered["USUBJID"].unique()

    return {
        "unique_subject_count": len(subjects),
        "subject_ids": list(subjects),
        "matching_events": filtered.to_dict(orient="records")
    }

    # -----------------------------
    # MAIN FUNCTION
    # -----------------------------
    def ask(self, question):
        parsed = self.parse_question(question)
        return self.run_query(parsed)
