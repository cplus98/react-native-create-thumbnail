declare module "react-native-video-processing" {
  export interface Config {
    url: string;
    timeStamp?: number;
    type?: "local" | "remote";
	format?: "jpeg" | "png";
	quality?: number;
	maxWidth?: number;
	maxHeight?: number;
	maxDirSize?: number;
	tolerance?: number;
  }

  export interface Thumbnail {
    path: string;
    width: number;
    height: number;
  }

  export function createThumbnail(config: Config): Promise<Thumbnail>;

  export interface CreateThumbnail {
    createThumbnail(config: Config): Promise<Thumbnail>;
  }

  const CreateThumbnail: CreateThumbnail;

  export default CreateThumbnail;
}
