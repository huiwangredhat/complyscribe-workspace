#!/bin/bash

# Get the commit hashes of the last two commits
commit_hashes=$(git log -n 2 --pretty=format:"%H")

# Split the hashes into an array (separated by newline)
commit_array=($commit_hashes)

# Output the updated files
files=$(git diff ${commit_array[1]} ${commit_array[0]} --name-only | grep "component-definition")
file_array=($files)
echo "List the updated component-definitions:"
echo "${file_array}"
# Loop over each file in the array and run git diff on it
for file in "${file_array[@]}"; do
    echo "Checking file: $file"
    # Run the git diff command and grep for "version": in the file
    version_changes=$(git diff ${commit_array[1]} ${commit_array[0]} "$file" | grep -E '^\+.*"version":|^\-.*"version":')
    # Extract origin and current version using sed
    origin_version=$(echo "$version_changes" | grep '^-' | sed -E 's/.*"version": "([^"]*)".*/\1/')
    current_version=$(echo "$version_changes" | grep '^\+' | sed -E 's/.*"version": "([^"]*)".*/\1/')
    
    # Output the origin and current version
    echo "origin_version: $origin_version"
    echo "current_version: $current_version"
    
    if [ -n "$origin_version" ] && [[ "$origin_version" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        correct_version=$(echo "$origin_version + 0.1" | bc)
        version=$(printf "%.1f\n" "$correct_version")
        echo "Update the version $version for $file"
        jq --arg new_version "$version" '.["component-definition"].metadata.version = $new_version' "$file" > file.json.tmp
        mv file.json.tmp "$file"
    fi
done
git add .
git commit --amend --no-edit
#git push origin test --force-with-lease
