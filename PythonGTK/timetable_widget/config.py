"""Configuration manager for TimetableWidget"""

import json
import os
from pathlib import Path


class Config:
    """Configuration manager using JSON file"""

    def __init__(self):
        self.config_dir = Path.home() / '.config' / 'timetable-widget'
        self.config_file = self.config_dir / 'config.json'
        self.config_dir.mkdir(parents=True, exist_ok=True)

        self._config = self._load_config()

    def _load_config(self):
        """Load configuration from file"""
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r') as f:
                    return json.load(f)
            except Exception as e:
                print(f"Failed to load config: {e}")
                return self._default_config()
        return self._default_config()

    def _default_config(self):
        """Get default configuration"""
        return {
            'backend_url': 'http://localhost:5000',
            'x': 100,
            'y': 100,
            'width': 400,
            'height': 500,
            'group': 0,
            'transparency': 0.95,
            'update_interval': 300,
            'auto_start': False
        }

    def save(self):
        """Save configuration to file"""
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self._config, f, indent=2)
        except Exception as e:
            print(f"Failed to save config: {e}")

    def get(self, key, default=None):
        """Get configuration value"""
        return self._config.get(key, default)

    def set(self, key, value):
        """Set configuration value"""
        self._config[key] = value
        self.save()

    @property
    def backend_url(self):
        return self.get('backend_url')

    @backend_url.setter
    def backend_url(self, value):
        self.set('backend_url', value)

    @property
    def position(self):
        return (self.get('x'), self.get('y'))

    @position.setter
    def position(self, value):
        self.set('x', value[0])
        self.set('y', value[1])

    @property
    def size(self):
        return (self.get('width'), self.get('height'))

    @size.setter
    def size(self, value):
        self.set('width', value[0])
        self.set('height', value[1])

    @property
    def group(self):
        return self.get('group', 0)

    @group.setter
    def group(self, value):
        self.set('group', value)

    @property
    def transparency(self):
        return self.get('transparency', 0.95)

    @transparency.setter
    def transparency(self, value):
        self.set('transparency', value)

    @property
    def update_interval(self):
        return self.get('update_interval', 300)

    @update_interval.setter
    def update_interval(self, value):
        self.set('update_interval', value)
