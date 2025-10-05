# YouTube Video Setup Guide

Your app is now ready to display YouTube videos, but **your API currently doesn't return any videos**. Here's how to add them:

## Current API Status

Checking your API at `https://lcc.live`:
- ✅ Returns data in the correct format (cameras array)
- ❌ No videos found - all entries have `"kind": "img"`

## How to Add Videos

### Option 1: Update Your Backend API

Modify your backend to include video entries in the `cameras` array:

```json
{
  "name": "LCC",
  "cameras": [
    {
      "id": "unique_video_id",
      "kind": "iframe",
      "src": "https://youtube.com/embed/VIDEO_ID",
      "alt": "Live webcam stream",
      "canyon": "lcc"
    }
  ]
}
```

### Option 2: Supported YouTube URL Formats

The app will automatically detect these YouTube URL formats in the `src` field:

1. **Embed URL** (recommended):
   ```
   https://youtube.com/embed/dQw4w9WgXcQ
   ```

2. **Watch URL**:
   ```
   https://youtube.com/watch?v=dQw4w9WgXcQ
   ```

3. **Short URL**:
   ```
   https://youtu.be/dQw4w9WgXcQ
   ```

4. **Iframe HTML**:
   ```html
   <iframe src="https://youtube.com/embed/dQw4w9WgXcQ"></iframe>
   ```

## Testing

### Test with Sample Data

To verify the video functionality is working, you can temporarily modify `APIService.swift` to add a test video to the fallback data:

```swift
private let fallbackLCCMedia: [MediaItem] = [
    "https://lcc.live/image/...",  // existing image
    "https://youtube.com/embed/dQw4w9WgXcQ",  // test video
    // ... rest of images
].compactMap { MediaItem.from(urlString: $0) }
```

Then build and run the app. You should see:
- The video appears in the grid with a play button overlay
- Tapping it opens a fullscreen YouTube player
- You can swipe between images and videos

### Check Debug Logs

When running in Xcode, you'll see debug logs like:
```
[APIService] 📊 Parsed 25 URL strings from API
[MediaItem] ✅ Detected YouTube video: https://youtube.com/embed/VIDEO_ID
[APIService] ✅ Fetched 25 LCC media items from API
```

If you see "Detected YouTube video" logs, the detection is working!

## Expected Behavior

Once videos are in your API:

1. **Grid View**: Videos show a thumbnail with a play button overlay
2. **Fullscreen View**: Videos play in an embedded YouTube player
3. **Navigation**: Swipe left/right to navigate between images and videos
4. **Mixed Content**: Images and videos can be mixed in any order

## Common Issues

### "I added videos but they're not showing"

1. Check the API response format matches exactly
2. Verify the YouTube URL is publicly accessible
3. Check Xcode debug logs for parsing errors
4. Make sure `kind` is set (though it's not required - any YouTube URL in `src` will work)

### "Videos show but won't play"

1. Check your internet connection
2. Verify the YouTube video is not private or region-restricted
3. Check iOS privacy settings allow network access

## Next Steps

1. Update your backend API to include video entries
2. Deploy the updated API
3. Build and test the iOS app
4. Videos will automatically appear in the grid!

The app code is ready - it just needs the video data from your API. 🎥
