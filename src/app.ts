import express from "express";
import { ParkingController } from "./controllers/parkingController";
import { ParkingService } from "./services/parkingService";
import { ParkingLotConfig } from "./types";

// Configuration
const config: ParkingLotConfig = {
  hourlyRate: 10,
  minimumInterval: 15, // 15-minute intervals
};

// Initialize Express app
const app = express();
const port = Number(process.env.PORT) || 3000;
const host = "0.0.0.0"; // Listen on all network interfaces

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Initialize services and controllers
const parkingService = new ParkingService(config);
const parkingController = new ParkingController(parkingService);

// Routes
app.get("/health", parkingController.healthCheck);
app.post("/entry", parkingController.handleEntry);
app.post("/exit", parkingController.handleExit);

// Start server
app.listen(port, host, () => {
  console.log(`Server running at http://${host}:${port}`);
});

export { app };
