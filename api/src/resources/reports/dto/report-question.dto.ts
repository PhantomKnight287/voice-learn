import { IsString } from 'class-validator';

export class ReportQuestionDTO {
  @IsString()
  title: string;

  @IsString()
  content: string;
}
