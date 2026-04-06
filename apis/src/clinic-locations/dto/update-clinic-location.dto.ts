import { PartialType } from '@nestjs/mapped-types';
import { CreateClinicLocationDto } from './create-clinic-location.dto';

export class UpdateClinicLocationDto extends PartialType(CreateClinicLocationDto) {}
