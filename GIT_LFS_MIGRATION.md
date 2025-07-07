# 📦 Git LFS Migration Notice

## ⚠️ Important: Repository has been migrated to Git LFS

This repository now uses **Git LFS** (Large File Storage) for snapshot test images and other binary assets.

### 🚀 For New Clones
```bash
git clone https://github.com/vonage/vonage-video-ios-app.git
cd vonage-video-ios-app
git lfs pull  # Download LFS files
```

### 🔄 For Existing Local Repositories
```bash
# Install Git LFS if not already installed
brew install git-lfs

# Initialize LFS
git lfs install

# Pull the latest changes (this will rewrite history)
git pull --rebase

# Download LFS files
git lfs pull
```

### 📸 What's Changed
- All PNG, JPG, and JPEG files are now stored in Git LFS
- Snapshot test images are managed more efficiently
- Repository clones are faster (images downloaded on-demand)
- Better collaboration for teams working with UI tests

### 🛠️ Working with Snapshots
```bash
# Run snapshot tests
./scripts/test-snapshots.sh

# Re-record snapshots
./scripts/test-snapshots.sh -r

# Check LFS files
git lfs ls-files
```

### 📚 More Information
- [Git LFS Documentation](https://git-lfs.github.io/)
- See `README.md` for complete setup instructions
