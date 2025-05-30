import { Request, Response } from 'express';
import { ParkingService } from '../services/parkingService';
import { ErrorCodes, ErrorResponse } from '../types';

export class ParkingController {
  constructor(private parkingService: ParkingService) {}

  /**
   * Health check endpoint
   */
  public healthCheck = (_req: Request, res: Response): void => {
    res.json({ status: 'healthy' });
  };

  /**
   * Handles vehicle entry requests
   */
  public handleEntry = (req: Request, res: Response): void => {
    try {
      const { plate, parkingLot } = req.query;

      if (!plate || !parkingLot || typeof plate !== 'string' || typeof parkingLot !== 'string') {
        const errorResponse: ErrorResponse = {
          error: 'Missing or invalid parameters: plate and parkingLot are required',
          code: ErrorCodes.MISSING_PARAMS
        };
        res.status(400).json(errorResponse);
        return;
      }

      const ticket = this.parkingService.createTicket(plate, parkingLot);
      res.json({ ticketId: ticket.ticketId });
    } catch (error) {
      const errorResponse: ErrorResponse = {
        error: 'Failed to process entry',
        code: ErrorCodes.INVALID_REQUEST
      };
      res.status(500).json(errorResponse);
    }
  };

  /**
   * Handles vehicle exit requests
   */
  public handleExit = (req: Request, res: Response): void => {
    try {
      const { ticketId } = req.query;

      if (!ticketId || typeof ticketId !== 'string') {
        const errorResponse: ErrorResponse = {
          error: 'Missing or invalid ticket ID',
          code: ErrorCodes.MISSING_PARAMS
        };
        res.status(400).json(errorResponse);
        return;
      }

      const exitResponse = this.parkingService.processExit(ticketId);
      res.json(exitResponse);
    } catch (error) {
      const errorResponse: ErrorResponse = {
        error: error instanceof Error ? error.message : 'Failed to process exit',
        code: error instanceof Error ? error.message : ErrorCodes.INVALID_REQUEST
      };
      res.status(error instanceof Error && error.message === ErrorCodes.TICKET_NOT_FOUND ? 404 : 500)
        .json(errorResponse);
    }
  };
} 