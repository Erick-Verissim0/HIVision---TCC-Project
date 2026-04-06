import { Module } from '@nestjs/common';
import { AppointmentsModule } from './appointments/appointments.module';
import { ClinicLocationsModule } from './clinic-locations/clinic-locations.module';
import { UsersModule } from './users/users.module';
import { PatientsModule } from './patients/patients.module';

@Module({
  imports: [UsersModule, PatientsModule, AppointmentsModule, ClinicLocationsModule],
})
export class AppModule {}
