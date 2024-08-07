import { IsOptional, IsString } from "class-validator";

export class CreateStackDTO{
    @IsString()
    name:string

    @IsString()
    @IsOptional()
    description?:string
}