# Chat Log Steering

## Rules

1. **Location:** Store the chat log at `chat-log/chat-log.md` in the Ashta_Chamma repo.
2. **Order:** Latest exchanges go at the TOP (reverse chronological). The most recent exchange should always appear first, right after the session header.
3. **Timestamps:** Include a timestamp (ISO 8601 format, e.g., `2026-06-30T14:30:00Z`) with each exchange.
4. **Session context:** Each session should begin with a session header that includes:
   - Session date and time
   - Repository being worked on (e.g., `srctgt/Ashta_Chamma`)
   - Session context: what the session is about, goals, and any relevant background
5. **Content:** Each exchange must include:
   - Timestamp
   - The user's question/request (verbatim)
   - Actions taken (tool calls, file operations, commands run)
   - The response/outcome
6. **Format:**

```markdown
# Chat Log

## Session: [Date] - [Context/Goal summary]

**Repository:** srctgt/Ashta_Chamma
**Session Context:** [Brief description of what this session covers]

---

### [Timestamp] - Exchange N

**User:** [verbatim question]

**Actions taken:**
- [list of actions/tool calls]

**Response:** [summary of response]

---
```

7. **Updates:** Append (prepend, since reverse chronological) to the log for every exchange in the session.
8. **Persistence:** At the end of a session or when asked, push the updated chat-log to the repo.
9. **Ask:** At the start of each new session, ask where to store the chat-log if no steering file exists.
