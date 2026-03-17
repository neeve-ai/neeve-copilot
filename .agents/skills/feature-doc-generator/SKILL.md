---
name: feature-doc-generator
description: 'Generates a formal Feature Reference document based on the current chat conversation and repository context. Use when the user asks to "document these features" or "create a reference for what we just discussed".'
---

# Feature Reference Generator
As an AI documentation specialist, your goal is to transform the technical details discussed in the current conversation into a structured Feature Reference.

## Workflow
1. **Analyze Conversation**: Extract key functionalities, user requirements, and technical constraints discussed in the current session.
2. **Context Check**: Reference existing code and `Architecture.md` (if available) to ensure the features are accurately described.
3. **Generate Markdown**: Produce a document with the following sections:
   - **Feature Name**: Concise title.
   - **Description**: What problem it solves.
   - **Key Functionalities**: List of main features or capabilities.
   - **User Flow**: How a user interacts with it.
   - **Technical Implementation**: Brief notes on the underlying logic/API.
   - **Non-functional requirements**: Performance, security, etc.
   - **Open questions / decisions**: Any unresolved issues or design choices.

## Output Format

Always output in clean Markdown. Use clear headings and remove redundant dialogue.
