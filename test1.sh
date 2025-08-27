# Start to fix the issue CPLYTM-967
  echo "Update the version of component-definiton before pushing"
  CHANGES_MADE=false

  # Process each component-definition file that was changed in the last commit
  git diff --name-only HEAD^ HEAD | grep "component-definition" > files.txt
  while IFS= read -r file; do
    echo "Checking file: $file"
    # Get the old version from the file in PREVIOUS commit.
    # If the file is new that the version is 1.0, default old to "0.9"
    old_version=$( (git show "HEAD^:$file" 2>/dev/null || echo "{}") | jq -r '.["component-definition"].metadata.version // "0.9"')

    # Get the current version from the file in latest commit
    current_version=$(jq -r '.["component-definition"].metadata.version' "$file")

    # Output the original and current version
    echo "origin_version: $old_version"
    echo "current_version: $current_version"
    
    # Correct the current version of component-definition to the expected version
    expected_version=$(printf "%.1f" "$(echo "$old_version + 0.1" | bc)")
    
    if [[ "$current_version" != "$expected_version" ]]; then
      echo "Update the version $expected_version for $file"
      jq --arg new_version "$expected_version" '.["component-definition"].metadata.version = $new_version' "$file" > file.json.tmp
      mv file.json.tmp "$file"
      git add $file
      CHANGES_MADE=true
    fi
  done < files.txt
  rm -f files.txt
  # Commit the version update
  if [ "$CHANGES_MADE" = true ]; then
    echo "amending commit with version corrections..."
    git commit --amend --no-edit
    echo "Finished: Commit amended successfully."
  else
    echo "Finished: No version corrections were necessary."
  fi
  # End to fix the issue CPLYTM-967
