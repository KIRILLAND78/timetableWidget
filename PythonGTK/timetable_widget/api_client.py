"""API client for backend communication"""

import requests
import json


class APIClient:
    """Client for TimetableWidget backend API"""

    def __init__(self, base_url):
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()

    def login(self, email, password):
        """Login to backend"""
        try:
            response = self.session.post(
                f'{self.base_url}/api/auth/login',
                json={'email': email, 'password': password},
                timeout=10
            )
            response.raise_for_status()
            data = response.json()
            return data.get('success', False), data.get('message', 'Unknown error')
        except requests.RequestException as e:
            return False, f'Connection error: {str(e)}'
        except json.JSONDecodeError:
            return False, 'Invalid response from server'

    def logout(self):
        """Logout from backend"""
        try:
            response = self.session.post(
                f'{self.base_url}/api/auth/logout',
                timeout=10
            )
            response.raise_for_status()
            return True
        except requests.RequestException:
            return False

    def check_auth_status(self):
        """Check authentication status"""
        try:
            response = self.session.get(
                f'{self.base_url}/api/auth/status',
                timeout=10
            )
            response.raise_for_status()
            data = response.json()
            return data.get('isAuthenticated', False), data.get('state', '')
        except requests.RequestException:
            return False, 'Connection error'
        except json.JSONDecodeError:
            return False, 'Invalid response'

    def get_timetable(self, today=True):
        """Get timetable data"""
        endpoint = 'today' if today else 'tomorrow'
        try:
            response = self.session.get(
                f'{self.base_url}/api/timetable/{endpoint}',
                timeout=10
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            raise Exception(f'Failed to fetch timetable: {str(e)}')
        except json.JSONDecodeError:
            raise Exception('Invalid timetable data')

    def get_settings(self):
        """Get settings from backend"""
        try:
            response = self.session.get(
                f'{self.base_url}/api/settings',
                timeout=10
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException:
            return None

    def save_settings(self, settings):
        """Save settings to backend"""
        try:
            response = self.session.put(
                f'{self.base_url}/api/settings',
                json=settings,
                timeout=10
            )
            response.raise_for_status()
            return True
        except requests.RequestException:
            return False
