import axios from "axios";
const apiUrl = (window._env_ && window._env_.REACT_APP_BACKEND_URL) || process.env.REACT_APP_BACKEND_URL || "http://localhost:8080/api/tasks";
console.log("API URL:", apiUrl)
export function getTasks() {
    return axios.get(apiUrl);
}

export function addTask(task) {
    return axios.post(apiUrl, task);
}

export function updateTask(id, task) {
    return axios.put(apiUrl + "/" + id, task);
}

export function deleteTask(id) {
    return axios.delete(apiUrl + "/" + id);
}
