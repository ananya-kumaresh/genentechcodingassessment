import streamlit as st
from agent import ClinicalTrialDataAgent

st.title("Clinical Trial AI Assistant")

question = st.text_input("Ask a question about AE data")

run = st.button("Run Analysis")

if run and question:
    agent = ClinicalTrialDataAgent()

    with st.spinner("Analyzing clinical data..."):
        result = agent.ask(question)

    st.subheader("Results")

    st.write("### Unique Subjects")
    st.write(result["unique_subject_count"])

    st.write("### Subject IDs")
    st.write(result["subject_ids"])

    st.write("### Matching Events")
    st.dataframe(result["matching_events"])
