# Question 4: GenAI Clinical Data Assistant

## Live App
Access the deployed application here:  
https://clinicalaiassistant.streamlit.app/

---

## Overview
This project implements a Generative AI-powered assistant that enables users to query a clinical adverse event (AE) dataset using natural language.

Instead of requiring knowledge of dataset column names, users can ask questions like:
- “Show subjects with severe adverse events”
- “Give me patients with headache”
- “Which subjects had cardiac-related events”

The system translates these questions into structured queries and retrieves results using Pandas.

---

## File Guide

### 1. `app.py`
- Main Streamlit application
- Provides the user interface
- Accepts natural language queries from users
- Calls the AI agent to process and display results

---

### 2. `agent.py`
- Core logic of the system
- Implements the `ClinicalTrialDataAgent` class
- Responsibilities:
  - Loads and processes the dataset (`adae.csv`)
  - Uses LangChain + OpenAI to convert natural language → structured JSON
  - Executes Pandas filtering based on LLM output
  - Returns:
    - Unique subject count
    - Subject IDs
    - Matching AE records

---

### 3. `adae.csv`
- Input dataset (clinical adverse event data)
- Contains:
  - USUBJID (subject ID)
  - AETERM (adverse event term)
  - AESEV (severity)
  - AESOC (body system)

---

### 4. `requirements.txt`
- Lists all Python dependencies required to run the project
- Includes:
  - streamlit
  - pandas
  - langchain
  - openai
  - python-dotenv
 
### 5. `test.py`
- Initializes the ClinicalTrialDataAgent
- Runs 3 sample clinical queries
- Prints:
  Query text
  Unique subject count
  Subject IDs
  Sample matching records
  
---

