# #! /bin/bash

# # ensure dates don't start with single quotes
# for file in *; do awk '{
# if ($1 == "date:") {
#   gsub("\047", "", $0); print;
# } else {
#   print $0;
# }
# }' "$file" > temp.md && mv temp.md $file ; done

# # fix the dates and add the three dashes as the first line
# for file in *; do awk '{
#   if ($1 == "date:") {
#     printf("%s %s\n", $1, $2);
#   } else {
#     print $0;
#   }
# }' "$file" > temp.md && mv temp.md $file ; done

# wrap dates with quotes that aren't wrapped in quotes
# for file in *; do awk '{
#   if ($1 == "dates:") {
#     if ($2 ~ /^"/) {
#       print $0;
#     } else {
#       printf("%s \"%s\"\n", $1, $2);
#     }
#   } else { print $0; }
# }' "$file" > temp.md && mv temp.md $file; done

# wrap tags with quotes that aren't wrapped in quotes
for file in *; do awk '{
  if ($1 == "tags:") {
      printf("%s [%s]\n", $1, $2);
  } else { print $0; }
}' "$file" > temp.md && mv temp.md $file; done

# # remove layout:post
# for file in *.md; do
#    grep -v "layout: post" $file > temp.md
#    mv temp.md $file
# done
