import { v4 as uuidv4 } from 'uuid';
import { ParkingTicket, ExitResponse, ParkingLotConfig, ErrorCodes } from '../types';

export class ParkingService {
  private parkingRecords: Map<string, ParkingTicket>;
  private config: ParkingLotConfig;

  constructor(config: ParkingLotConfig) {
    this.parkingRecords = new Map<string, ParkingTicket>();
    this.config = config;
  }

  /**
   * Records a vehicle entry and generates a parking ticket
   */
  public createTicket(licensePlate: string, parkingLotId: string): ParkingTicket {
    const ticket: ParkingTicket = {
      ticketId: uuidv4(),
      licensePlate,
      parkingLotId,
      entryTime: new Date()
    };

    this.parkingRecords.set(ticket.ticketId, ticket);
    return ticket;
  }

  /**
   * Processes vehicle exit and calculates parking fee
   * @throws {Error} If ticket is not found
   */
  public processExit(ticketId: string): ExitResponse {
    const ticket = this.parkingRecords.get(ticketId);
    if (!ticket) {
      throw new Error(ErrorCodes.TICKET_NOT_FOUND);
    }

    const response: ExitResponse = {
      licensePlate: ticket.licensePlate,
      totalParkedTime: this.formatDuration(ticket.entryTime),
      parkingLotId: ticket.parkingLotId,
      charge: this.calculateCharge(ticket.entryTime)
    };

    this.parkingRecords.delete(ticketId);
    return response;
  }

  /**
   * Calculates parking fee based on duration
   * Fee is prorated based on the minimum interval
   */
  private calculateCharge(entryTime: Date): number {
    const duration = new Date().getTime() - entryTime.getTime();
    const hours = duration / (1000 * 60 * 60);
    const intervals = Math.ceil(hours * (60 / this.config.minimumInterval));
    return (intervals * this.config.minimumInterval / 60) * this.config.hourlyRate;
  }

  /**
   * Formats the parking duration into a human-readable string
   */
  private formatDuration(entryTime: Date): string {
    const duration = new Date().getTime() - entryTime.getTime();
    const hours = Math.floor(duration / (1000 * 60 * 60));
    const minutes = Math.floor((duration % (1000 * 60 * 60)) / (1000 * 60));
    return `${hours}h ${minutes}m`;
  }
} 