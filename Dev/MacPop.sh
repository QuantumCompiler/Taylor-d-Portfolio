Target=$1

# Populate Profiles Directory
if [ "$Target" = "1" ]; then
    cp -r "Lorem Ipsum Profile" "/Users/taylor/Library/Containers/com.vici.taylordResume/Data/Documents/Profiles/Lorem Ipsum Profile"
    cp -r "Taylor Larrechea" "/Users/taylor/Library/Containers/com.vici.taylordResume/Data/Documents/Profiles/Taylor Larrechea"
# Populate Jobs Directory
elif [ "$Target" = "2" ]; then
    cp -r "Lorem Ipsum Job" "/Users/taylor/Library/Containers/com.vici.taylordResume/Data/Documents/Jobs/Lorem Ipsum Job"
    cp -r "Software Engineer, UX Platform Foundation, Full Stack" "/Users/taylor/Library/Containers/com.vici.taylordResume/Data/Documents/Jobs/Software Engineer, UX Platform Foundation, Full Stack"
# Populate Jobs, Profiles
elif [ "$Target" = "3" ]; then
    cp -r "Lorem Ipsum Profile" "/Users/taylor/Library/Containers/com.vici.taylordResume/Data/Documents/Profiles/Lorem Ipsum Profile"
    cp -r "Taylor Larrechea" "/Users/taylor/Library/Containers/com.vici.taylordResume/Data/Documents/Profiles/Taylor Larrechea"
    cp -r "Lorem Ipsum Job" "/Users/taylor/Library/Containers/com.vici.taylordResume/Data/Documents/Jobs/Lorem Ipsum Job"
    cp -r "Software Engineer, UX Platform Foundation, Full Stack" "/Users/taylor/Library/Containers/com.vici.taylordResume/Data/Documents/Jobs/Software Engineer, UX Platform Foundation, Full Stack"
fi