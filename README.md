# MDF Public Adjuster Management System

## Recent Updates

### Claims Management Enhancements (April 2023)

#### New Features

1. **Resizable Table Columns**
   - Users can now resize columns in the claims table by dragging the column headers
   - Column widths are saved to localStorage for persistence between sessions
   - Improves readability and allows customization of the view based on user preference

2. **Expandable/Collapsible Claim Groups**
   - Added ability to expand or collapse individual claim groups
   - "Expand/Collapse All" button to toggle all groups at once
   - First group is expanded by default, others are collapsed
   - Improves navigation when dealing with many claim groups

3. **Detailed Claim View**
   - Comprehensive claim details page showing all information from Monday.com
   - Interactive map showing claim location using Leaflet
   - Proper formatting for different data types (currency, percentages, dates)
   - Organized sections for better information hierarchy

4. **Client Integration**
   - Added client information to claim details page
   - Fetches client data from connected Monday.com board
   - Displays contact information, address, and notes
   - Link to view the client directly in Monday.com

#### Technical Improvements

1. **Monday.com API Integration**
   - Created dedicated `MondayApiService` for API interactions
   - Improved error handling and logging
   - Support for GraphQL queries to fetch related data
   - Proper authentication with Monday.com API

2. **Performance Optimizations**
   - Lazy loading of claim data
   - Pagination for large claim groups
   - Conditional rendering of complex UI elements

3. **Error Handling**
   - Detailed error messages in development environment
   - User-friendly error messages in production
   - Graceful fallbacks when data is missing or API calls fail

#### Setup Requirements

1. **Environment Variables**
   - `MONDAY_API_KEY`: Your Monday.com API v2 token
   - `MONDAY_CLAIMS_BOARD_ID`: ID of your Claims board in Monday.com
   - `MONDAY_CLIENTS_BOARD_ID`: ID of your Clients board in Monday.com

2. **External Dependencies**
   - Leaflet.js for maps (included via CDN)
   - Bootstrap 5 for UI components
   - Bootstrap Icons for iconography

## Getting Started

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/your-username/mdf-public-adjuster.git
   cd mdf-public-adjuster
   ```

2. Install dependencies
   ```bash
   bundle install
   yarn install
   ```

3. Set up environment variables
   Create a `.env` file in the root directory with the following:
   ```
   MONDAY_API_KEY=your_monday_api_key
   MONDAY_CLAIMS_BOARD_ID=your_claims_board_id
   MONDAY_CLIENTS_BOARD_ID=your_clients_board_id
   ```

4. Set up the database
   ```bash
   rails db:create db:migrate
   ```

5. Start the server
   ```bash
   rails server
   ```

### Usage

1. **Claims Dashboard**
   - Navigate to `/claims` to view all claims
   - Use filters and sorting options to find specific claims
   - Resize columns by dragging the column headers
   - Expand/collapse groups using the toggle buttons

2. **Claim Details**
   - Click on a claim name to view detailed information
   - View client information if available
   - See claim location on the interactive map
   - Access related documents and notes

3. **Client Management**
   - View client information linked to claims
   - Access client contact details and notes
   - View all claims associated with a client

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
