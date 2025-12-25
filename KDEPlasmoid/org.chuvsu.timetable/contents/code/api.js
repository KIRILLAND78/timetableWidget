// API helper for backend communication
.pragma library

var backendUrl = "http://localhost:5678";

function setBackendUrl(url) {
    backendUrl = url;
}

function apiRequest(method, endpoint, data, callback) {
    var xhr = new XMLHttpRequest();
    var url = backendUrl + endpoint;

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (callback) {
                callback(xhr.status, xhr.responseText);
            }
        }
    };

    xhr.open(method, url, true);
    xhr.setRequestHeader("Content-Type", "application/json");

    if (data) {
        xhr.send(JSON.stringify(data));
    } else {
        xhr.send();
    }
}

function login(email, password, callback) {
    apiRequest("POST", "/api/auth/login", {
        email: email,
        password: password
    }, callback);
}

function logout(callback) {
    apiRequest("POST", "/api/auth/logout", null, callback);
}

function checkAuthStatus(callback) {
    apiRequest("GET", "/api/auth/status", null, callback);
}

function getTimetable(isToday, callback) {
    var endpoint = isToday ? "/api/timetable/today" : "/api/timetable/tomorrow";
    apiRequest("GET", endpoint, null, callback);
}

function getSettings(callback) {
    apiRequest("GET", "/api/settings", null, callback);
}

function saveSettings(settings, callback) {
    apiRequest("PUT", "/api/settings", settings, callback);
}
