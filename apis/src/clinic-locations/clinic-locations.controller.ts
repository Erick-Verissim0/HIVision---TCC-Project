import { Body, Controller, Delete, Get, HttpCode, Param, Patch, Post, Query } from '@nestjs/common';
import { CreateClinicLocationDto } from './dto/create-clinic-location.dto';
import { UpdateClinicLocationDto } from './dto/update-clinic-location.dto';
import { ClinicLocationsService } from './clinic-locations.service';

@Controller('clinic-locations')
export class ClinicLocationsController {
  constructor(private readonly clinicLocationsService: ClinicLocationsService) {}

  @Post()
  create(@Body() dto: CreateClinicLocationDto) {
    return this.clinicLocationsService.create(dto);
  }

  @Get()
  findAll(
    @Query('city') city?: string,
    @Query('street') street?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.clinicLocationsService.findAll({
      city,
      street,
      page: page !== undefined ? Number(page) : undefined,
      limit: limit !== undefined ? Number(limit) : undefined,
    });
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.clinicLocationsService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateClinicLocationDto) {
    return this.clinicLocationsService.update(id, dto);
  }

  @Delete(':id')
  @HttpCode(204)
  remove(@Param('id') id: string) {
    return this.clinicLocationsService.remove(id);
  }
}
