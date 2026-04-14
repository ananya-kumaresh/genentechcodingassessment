import streamlit as st
import pandas as pd
from agent import ClinicalTrialDataAgent

st.set_page_config(page_title="Clinical AE Assistant", layout="wide")

st.title("Clinical Adverse Event GenAI Assistant")

question = st.text_input("Enter your question")
run = st.button("Run Analysis")

if run and question:

    # Create Agent
    agent = ClinicalTrialDataAgent() 

    with st.spinner("Analyzing..."):
        result = agent.ask(question) 

    st.success("Done")

    st.subheader("Summary")
    st.metric("Unique Subjects", result["unique_subject_count"])

    st.subheader("Matching AE Events")
    df_events = pd.DataFrame(result["matching_events"])

    if not df_events.empty:
        st.dataframe(df_events, use_container_width=True)
