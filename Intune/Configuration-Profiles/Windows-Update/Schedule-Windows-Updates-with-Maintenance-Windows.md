
# Microsoft Intune - Schedule Windows Updates with Maintenance Windows

## Overview

Maintenance Windows in Microsoft Intune allows administrators to control when Windows Update installations and restarts can occur on managed Windows devices.

The feature helps prevent unexpected interruptions on devices such as:

- Kiosk devices
- Information screens
- Medical equipment
- Manufacturing devices

## Requirements

- Windows 11 24H2 or later
- February 2026 security update or later
- Microsoft Intune or Group Policy management

## Configure Maintenance Windows

Navigate to:

Devices → Manage devices → Maintenance windows

Create a new maintenance window and configure:

- Update action
- Schedule
- Duration
- Assignments

## Example Configuration

| Setting | Value |
|----------|----------|
| Update action | Download, install and restart |
| Schedule | Monthly |
| Week | First |
| Day | Friday |
| Start time | 17:00 |
| Duration | 2 hours |

## Recommended Configuration for Kiosk Devices

| Setting | Value |
|----------|----------|
| Update action | Install and restart |
| Frequency | Weekly |
| Day | Sunday |
| Start time | 17:00 |
| Duration | 2 hours |

## Benefits

- Reduced business disruption
- Controlled restart behavior
- Improved update compliance
- Better user experience

## References

https://techtrendsandinsights.blogspot.com/2026/11/microsoft-intune-schedule-windows.html
