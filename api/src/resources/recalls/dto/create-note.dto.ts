import { IsString } from 'class-validator';

export class CreateNoteDTO {
  @IsString()
  title: string;

  @IsString()
  description: string;
}
