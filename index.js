import { NativeModules } from "react-native";

const { CreateThumbnail } = NativeModules;

export const { create: createThumbnail, trim: trimVideo } = CreateThumbnail;
export default CreateThumbnail;
