#!/bin/bash

read -r -d '' PROMPT << EOM
You job is to extract text from the images I provide you. Extract every bit of the text in the image. Don't say anything just do your job. Text should be same as in the images.

Things to avoid:
- Don't miss anything to extract from the images

Things to include:
- Include everything, even anything inside [], (), {} or anything.
- Include any repetitive things like "..." or anything
- If you think there is any mistake in image just include it too
EOM