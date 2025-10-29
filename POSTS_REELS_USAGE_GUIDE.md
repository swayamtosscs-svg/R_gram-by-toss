# Posts & Reels Management - User Guide

यह guide आपको बताता है कि app में Posts और Reels functionality कहाँ use कर सकते हैं।

## 📍 Where to Use Posts & Reels Functionality

### 1. **Upload Posts/Reels** 📤

#### **Method 1: Bottom Navigation "Add" Button**
1. App के bottom navigation bar में **"Add"** button पर click करें
2. यह आपको `AddOptionsScreen` पर ले जाएगा
3. वहाँ आप देखेंगे:
   - **Upload Story** - Stories के लिए
   - **Upload Post** - Posts के लिए (✅ NEW)
   - **Upload Reel** - Reels के लिए (✅ NEW)
   - **Create Baba Ji Page** - Baba Ji pages के लिए
   - **Live Stream** - Live streaming के लिए

#### **Method 2: Content Type Selection Screen**
1. किसी भी screen से `ContentTypeSelectionScreen` पर navigate करें
2. वहाँ तीन options हैं:
   - **Post** button - Image, video, या text-only post upload करने के लिए
   - **Reel** button - Video reel upload करने के लिए
   - **Story** button - Story upload करने के लिए

### 2. **View Your Posts/Reels** 👀

#### **Profile Screen (Account Tab)**
1. Bottom navigation में **"Account"** tab पर जाएं
2. Profile screen में तीन tabs हैं:
   - **Posts Tab** - आपके सभी posts grid format में दिखेंगे
   - **Reels Tab** - आपके सभी reels grid format में दिखेंगे
   - **Tagged Tab** - Tagged content दिखेगा

3. Profile header में आप देख सकते हैं:
   - **Posts count** - आपके कुल posts की संख्या
   - **Reels count** - आपके कुल reels की संख्या
   - **Followers count**
   - **Following count**

### 3. **Post Upload Features** 📸

जब आप **"Upload Post"** option select करते हैं:

- **Image Posts**: Gallery से image select करें या camera से photo लें
- **Video Posts**: Gallery से video select करें या camera से record करें
- **Text-Only Posts**: Caption लिखकर बिना media के भी post कर सकते हैं
- **Caption**: Optional - आप अपनी post के लिए caption add कर सकते हैं
- **Auto-Navigation**: Post upload होने के बाद automatically profile screen पर जाएगा

### 4. **Reel Upload Features** 🎬

जब आप **"Upload Reel"** option select करते हैं:

- **Video Required**: Reel के लिए video file जरूरी है
- **Video Selection**: Gallery से video select करें या camera से record करें
- **Caption**: Optional - आप अपनी reel के लिए caption add कर सकते हैं
- **Auto-Navigation**: Reel upload होने के बाद automatically profile screen पर जाएगा

### 5. **View Posts/Reels Details** 🔍

- Profile screen के Posts/Reels tab में किसी भी item पर tap करें
- यह आपको `PostFullViewScreen` पर ले जाएगा जहाँ आप:
  - Full-size image/video देख सकते हैं
  - Caption पढ़ सकते हैं
  - Like/Unlike कर सकते हैं (अगर implemented है)
  - Comments देख सकते हैं (अगर implemented है)

### 6. **Refresh Content** 🔄

Profile screen में content refresh करने के लिए:

- **Pull-to-Refresh**: Screen को नीचे खींचें (pull down)
- यह automatically:
  - Posts की नई list fetch करेगा
  - Reels की नई list fetch करेगा
  - Posts/Reels counts update करेगा

### 7. **Navigation Flow** 🗺️

```
Bottom Nav "Add" Button
    ↓
AddOptionsScreen
    ↓
[Select Upload Post/Reel]
    ↓
PostUploadScreen / ReelUploadScreen
    ↓
[Upload Success]
    ↓
Profile Screen (Auto-navigate)
    ↓
Posts/Reels Tab (Shows new content)
```

## 📱 Quick Access Points

### **Main Entry Points:**
1. **Bottom Navigation → "Add" Button** → Upload Post/Reel
2. **Profile Screen → Posts Tab** → View all your posts
3. **Profile Screen → Reels Tab** → View all your reels

### **Navigation:**
- `/add-options` - AddOptionsScreen route
- `/post-upload` - PostUploadScreen route  
- `/reel-upload` - ReelUploadScreen route
- `/profile` - ProfileScreen route

## ✨ Key Features

✅ **Upload Posts** - Images, videos, या text-only  
✅ **Upload Reels** - Video reels  
✅ **View in Profile** - Grid layout में posts/reels देखें  
✅ **Auto Refresh** - Upload के बाद automatically refresh  
✅ **Pull to Refresh** - Manual refresh support  
✅ **Real-time Counts** - Posts/Reels की count automatically update  
✅ **Navigation** - Easy navigation between screens  

## 🔧 Technical Implementation

### **Services Used:**
- `PostsManagementService` - Posts के लिए API calls
- `ReelsManagementService` - Reels के लिए API calls

### **API Endpoints:**
- Posts: `http://103.14.120.163:8081/api/posts-management/*`
- Reels: `http://103.14.120.163:8081/api/reels-management/*`

### **Screens:**
- `PostUploadScreen` - Post upload interface
- `ReelUploadScreen` - Reel upload interface  
- `ProfileScreen` - Posts/Reels display
- `AddOptionsScreen` - Upload options menu
- `ContentTypeSelectionScreen` - Content type selection

## 📝 Notes

1. **Authentication Required**: Posts/Reels upload करने के लिए login होना जरूरी है
2. **Auto-Navigation**: Successful upload के बाद automatically profile screen पर navigate करता है
3. **Real-time Updates**: Profile screen में counts और content real-time update होता है
4. **Pull Refresh**: Profile screen में pull-to-refresh feature available है

---

**Last Updated**: 2024
**Version**: 1.0.0

