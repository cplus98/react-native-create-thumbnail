# react-native-video-processing

iOS/Android video trimmer and thumbnail generator with support for both local and remote videos. `react-native-video-processing` is a wrapper around
[`AVAssetImageGenerator`](https://developer.apple.com/documentation/avfoundation/avassetimagegenerator?language=objc) (iOS) and [`MediaMetadataRetriever`](https://developer.android.com/reference/android/media/MediaMetadataRetriever) (Android)

## Getting started

1. Install library from `npm`

   ```bash
   yarn add react-native-video-processing
   ```

   or

   ```bash
   npm i react-native-video-processing
   ```

2. Link native code

   With autolinking (react-native 0.60+)

   ```bash
   cd ios && pod install
   ```

   Pre 0.60

   ```bash
   react-native link react-native-video-processing
   ```

## Usage

```javascript
import { createThumbnail } from "react-native-video-processing";

createThumbnail({
  url: "<path to video file>",
  type: "local"
  timeStamp: 5000
})
  .then(response => {
    console.log({ response });
    this.setState({
      status: "Thumbnail received",
      thumbnail: response.path
    });
  })
  .catch(err => console.log({ err }));
```

## Request Object

| Property  |            Type             | Description                                        |
| --------- | :-------------------------: | :------------------------------------------------- |
| url       |     `String` (required)     | Path to video file (local or remote)               |
| timeStamp |   `Number` (default `0`)    | Thumbnail timestamp (in milliseconds)              |
| format    |  `String` (default `jpeg`)  | Thumbnail format, can be one of: `jpeg`, or `png`  |
| quality   |  `Number` (default `100`)   | Thumbnail quality (0 to 100)                       |
| maxWidth  |  `Number` (default `0`)     | Maximum thumbnail width (Using with maxHeight)     |
| maxHeight |  `Number` (default `0`).    | Maximum thumbnail width (Using with maxWidth)      |
| tolerance |  `Number` (default `1`)     | Thumbnail tolerance (in milliseconds, only iOS)    |

## Response Object

| Property |   Type   | Description                 |
| -------- | :------: | :-------------------------- |
| path     | `String` | Path to generated thumbnail |
| width    | `Number` | Thumbnail width             |
| height   | `Number` | Thumbnail height            |

#### Notes

Requires following Permissions on android

```bash
READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE
```

#### Limitations

Remote videos aren't supported on android sdk_version < 14

#### Credits

- [`react-native-thumbnail`](https://www.npmjs.com/package/react-native-thumbnail) - A great source of inspiration
- This project was bootstrapped with [`create-react-native-module`](https://github.com/brodybits/create-react-native-module)

#### Maintenance Status

**Active:** Bug reports, feature requests and pull requests are welcome.
