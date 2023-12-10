/**
 * A cloud WebSocket interface
 */
pub interface IWebSocket extends std.IResource {
  /**
   * Adds an inflight handler to the WebSocket for connection requests.
   */
  onConnect(handler: inflight(str): void): void;
  /**
   * Adds an inflight handler to the WebSocket for disconnection requests.
   */
  onDisconnect(handler: inflight(str): void): void;
  /**
   * Adds an inflight handler to the WebSocket for processing message requests.
   */
  onMessage(handler: inflight(str, str): void): void;

  /**
   * Initialize the WebSocket (necessary only in the sim, to be removed in the future).
   */
  initialize(): void;

  /**
   * Sends a message through the WebSocket with inflight handling.
   */
  inflight sendMessage(connectionId: str, message: str);
  /**
   * Retrieves the URL associated with the WebSocket on inflight.
   */
   inflight inflightUrl(): str;
  /**
   * Retrieves the URL associated with the WebSocket on preflight.
   */
  url(): str;
}

/**
 * Options for `WebSocket`.
 */
pub struct WebSocketProps {
  /** WebSocket api name */
  name: str;
  /**
   * Stage name
   * @default prod
   */
  stageName: str?;
}
