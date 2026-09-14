---
name: clip-to-social
version: 1.0.0
description: Turn a video clip transcript into concise X/Twitter, LinkedIn, and YouTube Short promotional copy. Use when the user shares a transcript or clip excerpt and asks for social posts, captions, or a Short title.
user-invocable: true
argument-hint: "[transcript or clip excerpt]"
---

# Clip to Social

Turn a rough video transcript into platform-ready social copy without flattening the speaker's point or inventing context.

## Workflow

1. Ignore timestamps, duplicated fragments, filler words, false starts, and transcription errors unless they affect the meaning.
2. Identify the clip's strongest single idea. Prefer the sharpest useful takeaway over a chronological summary.
3. Preserve the speaker's level of certainty. Do not turn estimates, speculation, or phrases such as "something like that" into precise factual claims.
4. Generalize named products or vendors when the idea is broader than the specific example. Keep the name when it is essential to understanding the clip.
5. Draft only the platforms the user requests. When the request names no platforms, produce X/Twitter, LinkedIn, and YouTube Short copy.
6. Validate every platform constraint before returning the drafts.

## Platform Rules

### X/Twitter

- Maximum 280 characters, including spaces, punctuation, line breaks, links, and any other visible characters.
- Do not use hashtags.
- Count the final draft after all edits and show the count outside the post as `X/Twitter (N/280)`.
- If a link is included, count the characters in the URL as written rather than assuming a shortened length.
- Lead with the central idea. Remove setup, repetition, and generic calls to action before sacrificing the point.

### LinkedIn

- Use no more than two paragraphs, including any hashtag line.
- The first paragraph should carry the idea. Use the second only when it adds useful context, a conclusion, or hashtags.
- Reuse the X/Twitter post verbatim when it already communicates the point well. Do not lengthen it merely because LinkedIn permits more text.
- When the user requests hashtags, add a small relevant set at the end of the second paragraph. Avoid hashtag stuffing.

### YouTube Short

- Provide a concise, accurate title followed by a short description or caption.
- Make the title specific and interesting without clickbait or claims the transcript cannot support.
- When the user requests hashtags, add a small relevant set, including `#Shorts`.

## Writing Style

- Write like a knowledgeable person sharing a useful observation, not a brand campaign.
- Prefer plain language, concrete examples, and short sentences.
- Avoid generic openings such as "In today's fast-paced world" and empty conclusions such as "The future is here."
- Do not use em dashes or emojis unless the user asks for them.
- Do not invent links, names, claims, calls to action, or speaker attribution.
- Do not mention transcript cleanup or explain the drafting process unless the transcript is too ambiguous to use safely.

## Output

Label each requested platform clearly and present complete, ready-to-paste copy. Put the X/Twitter character count in its heading, not inside the post. Include the YouTube Short title separately from its description.

If the same copy works for X/Twitter and LinkedIn, say so and reuse it rather than manufacturing variation.
