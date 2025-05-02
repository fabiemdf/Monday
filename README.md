# MDF Public Adjuster Management System

## Recent Updates

### Integration Enhancements (April 24, 2025)

#### New Features

1. **Employee Management**
   - Added complete Employee management section
   - View all employees grouped by department
   - Local editing interface for employee details
   - Direct sync with Monday.com
   - Fields supported:
     - Name
     - Email
     - Phone (with US formatting)
     - Position
     - Status
     - Notes

2. **Insurance Representatives Management**
   - New section for managing Insurance Representatives
   - View and edit capabilities
   - Integration with Monday.com board
   - Grouped view by categories

3. **Adjusters Management**
   - Added Adjusters section with Monday.com integration
   - Complete CRUD interface
   - Board ID: 9000027904

#### Technical Improvements

1. **Monday.com API Integration**
   - Enhanced mutation support for complex column types
   - Improved error handling and debugging
   - Better column value formatting for:
     - Email columns
     - Phone columns (with country code)
     - Status columns
     - Text columns

2. **UI Enhancements**
   - Consistent layout across all sections
   - Bootstrap 5 styling
   - Mobile-responsive tables
   - Action buttons with icons
   - Improved navigation

#### Known Issues

1. **Email Updates**
   - Email column updates sometimes fail (under investigation)
   - Workaround: Update emails directly in Monday.com

#### Future Plans

1. **Short Term (Next Sprint)**
   - Fix email column update issues
   - Add bulk update capabilities
   - Implement sorting and filtering
   - Add search functionality

2. **Long Term**
   - Add document attachment support
   - Implement real-time updates
   - Add calendar integration
   - Create reporting dashboard

#### Setup Requirements

1. **New Environment Variables**
   ```
   MONDAY_EMPLOYEES_BOARD_ID=9000122678
   MONDAY_INSURANCE_REPS_BOARD_ID=8876787198
   MONDAY_ADJUSTERS_BOARD_ID=9000027904
   ```

2. **Additional Dependencies**
   - Bootstrap Icons for improved UI
   - Enhanced Monday.com API integration

## Contributing

Please refer to our contributing guidelines and code style guide.

## License

This project remains under the MIT License - see the LICENSE file for details.

---
Last Updated: April 24, 2025
