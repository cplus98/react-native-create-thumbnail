declare module "react-native-video-processing" {
	export interface ThumbnailConfig {
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
  
	const TrimVideo: CreateThumbnail;
  
	export interface TrimConfig {
	  url: string;
	  startTime?: number;
	  endTime?: number;
	  maxDirSize?: number;
	}
  
	export interface Trim {
	  path: string;
	}
  
	export function createThumbnail(config: ThumbnailConfig): Promise<Thumbnail>;
	export function trimVideo(config: TrimConfig): Promise<Trim>;
  
	export interface CreateThumbnail {
	  createThumbnail(config: ThumbnailConfig): Promise<Thumbnail>;
	  trimVideo(config: TrimConfig): Promise<Thumbnail>;
	}
	
	export default CreateThumbnail;
  }
  