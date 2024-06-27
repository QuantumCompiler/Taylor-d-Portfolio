Target=$1

# Populate Profiles Directory
if [ "$Target" = "1" ]; then
    cp -r "Test Profile" "/Users/taylor/Library/Containers/com.vici.taylordResume/Data/Documents/Profiles/Test Profile"
# Populate Jobs Directory
elif [ "$Target" = "2" ]; then
    cp -r "Test Job" "/Users/taylor/Library/Containers/com.vici.taylordResume/Data/Documents/Jobs/Test Job"
# Populate Jobs, Profiles
elif [ "$Target" = "3" ]; then
    cp -r "Test Profile" "/Users/taylor/Library/Containers/com.vici.taylordResume/Data/Documents/Profiles/Test Profile"
    cp -r "Test Job" "/Users/taylor/Library/Containers/com.vici.taylordResume/Data/Documents/Jobs/Test Job"
fi