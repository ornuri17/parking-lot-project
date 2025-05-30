export interface ParkingTicket {
  ticketId: string;
  licensePlate: string;
  parkingLotId: string;
  entryTime: Date;
}

export interface ExitResponse {
  licensePlate: string;
  totalParkedTime: string;
  parkingLotId: string;
  charge: number;
}

export interface ErrorResponse {
  error: string;
  code: string;
}

export enum ErrorCodes {
  MISSING_PARAMS = 'MISSING_PARAMS',
  TICKET_NOT_FOUND = 'TICKET_NOT_FOUND',
  INVALID_REQUEST = 'INVALID_REQUEST'
}

export interface ParkingLotConfig {
  hourlyRate: number;
  minimumInterval: number; // in minutes
} 