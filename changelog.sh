#!/usr/bin/env bash
##---------------------------------------------------------------------------------------
## Author: Mifas
## 
## Description:
## This script will allow you to create CHANGELOG.md based on your tags and PR
## For the first time your can run changelog.sh to create full change log file
## And If you want to edit any changes you can edit the file itself
## And If you released any new version after creation of CHANGELOG.md
## Run changelog.sh --latest. This is get latest tag information and update CHANGELOG.md
##---------------------------------------------------------------------------------------
BITBUCKET_REPO="https://bitbucket.org/username/repo"
CHANGELOG_FILENAME="CHANGELOG.md"

function print_new()
{
  current_tag=$(git describe)
  previous_tag=$(cat .git/latest.tag)

  if [ "$current_tag" != "$previous_tag" ];then
    # Deleting `Change Log` Heading
    sed -i '1d' $CHANGELOG_FILENAME;


    period="${current_tag}...${previous_tag}"
    tag_date=$(git log -1 --pretty=format:'%ad' --date=short ${current_tag})

    output="# Change Log\n\n"

    # Print: <tag> (YYYY-MM-DD)
    # 1.0.2 (2019-02-26)
    output+=$(printf '## [%s](%s/browse?at=refs/tags/%s) (%s)\\n\\n' "$current_tag" "$BITBUCKET_REPO" "$current_tag" "$tag_date")

    pr=(`git log ${period} --pretty=format:'-  %s' | grep -o -E '#[0-9]+'`)
    pr_id="${pr//[^0-9]/}"

    if [ "$pr_id" != "" ];then
        output+=$(printf "Pull request - [#$pr_id](${BITBUCKET_REPO}/pull-requests/$pr_id/overview)")
        output+="\n\n"
    fi

    
    output+=$(git log $period --no-merges --pretty=format:"- %s (%an in [%h]($BITBUCKET_REPO/commits/%H))" 2>&1)
    output+=$(printf "\\n\\n")

    output+=$(cat $CHANGELOG_FILENAME)
    echo -en "$output" > $CHANGELOG_FILENAME

    # Updating latest tag
    echo ${current_tag} > .git/latest.tag
  else
    echo "All tags are already up to date. Please run"
    echo "git pull origin master --tags"
  fi  
}

function print_all()
{
  counter=0;
  TAGS=(`git tag --sort=-creatordate`)
  printf '# Change Log\n\n' > $CHANGELOG_FILENAME
  for i in "${!TAGS[@]}"; do
    current_tag=${TAGS[i]}
    previous_tag="${TAGS[(i+1)]}"

    period="${current_tag}...${previous_tag}"

    tag_date=$(git log -1 --pretty=format:'%ad' --date=short ${current_tag})

    if [ "$previous_tag" = "" ];then
      previous_tag=""
      period="${current_tag}"
    fi
    
    # Print: <tag> (YYYY-MM-DD)
    # 1.0.2 (2019-02-26)
    printf '## [%s](%s/browse?at=refs/tags/%s) (%s)\n\n' "$current_tag" "$BITBUCKET_REPO" "$current_tag" "${tag_date}"  >> $CHANGELOG_FILENAME

    pr=(`git log ${period} --pretty=format:'-  %s' | grep -o -E '#[0-9]+'`)
    pr_id="${pr//[^0-9]/}"

    if [ "$pr_id" != "" ];then
        # Print: Pull request #<PR_ID>
        # Pull request - #23
        printf 'Pull request - [#%s](%s/pull-requests/%s/overview)\n\n' "$pr_id" "$BITBUCKET_REPO" "$pr_id" >> $CHANGELOG_FILENAME
    fi

    # Print: Commit log between <current_tag>...<previous_tag> With 
    # <message> (<author> in <hash>)
    git log $period --no-merges --pretty=format:"- %s (%an in [%h]($BITBUCKET_REPO/commits/%H))" >> $CHANGELOG_FILENAME

    printf '\n\n' >> $CHANGELOG_FILENAME

    counter=$((counter+1))

    if [ "$i" = 0 ];then
      echo ${current_tag} > .git/latest.tag
    fi

  done
}

while [[ "$#" -gt 0 ]]; do case $1 in
  -a|--all) all="$2"; shift;;
  -n|--new) new=1;;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

if [ $new ]; then
    print_new
else
    print_all
fi

