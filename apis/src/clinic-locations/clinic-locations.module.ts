import { Module } from '@nestjs/common';
import { UsersModule } from '../users/users.module';
import { ClinicLocationsController } from './clinic-locations.controller';
import { ClinicLocationsService } from './clinic-locations.service';

@Module({
  imports: [UsersModule],
  controllers: [ClinicLocationsController],
  providers: [ClinicLocationsService],
})
export class ClinicLocationsModule {}
