import React from "react";
import Tasks from "./Tasks";
import { Paper, TextField, Checkbox, Button } from "@material-ui/core";
import "./App.css";

class App extends Tasks {
    state = { tasks: [], currentTask: "" };

    render() {
        const { tasks, currentTask } = this.state;
        return (
            <div className="app">
                <header className="app-header">
                    <h1>My To-Do List</h1>
                </header>
                <div className="main-content">
                    <Paper elevation={3} className="todo-container">
                        <form onSubmit={this.handleSubmit} className="task-form">
                            <TextField
                                variant="outlined"
                                size="small"
                                className="task-input"
                                value={currentTask}
                                required={true}
                                onChange={this.handleChange}
                                placeholder="Add New TO-DO"
                            />
                            <Button className="add-task-btn" color="primary" variant="contained" type="submit">
                                ADD TASK
                            </Button>
                        </form>
                        <div className="tasks-list">
                            {tasks.map((task) => (
                                <Paper key={task._id} className="task-item">
                                    <Checkbox
                                        checked={task.completed}
                                        onClick={() => this.handleUpdate(task._id)}
                                        color="primary"
                                    />
                                    <div className={task.completed ? "task-text completed" : "task-text"}>
                                        {task.task}
                                        <div className="timestamp">
                                            {task.createdAt ? new Date(task.createdAt).toLocaleString() : ''}
                                        </div>
                                    </div>
                                    <Button onClick={() => this.handleDelete(task._id)} color="secondary" className="delete-task-btn">
                                        Delete
                                    </Button>
                                </Paper>
                            ))}
                        </div>
                    </Paper>
                </div>
                <div className="version-footer">
                    {process.env.REACT_APP_VERSION || "v1.0.0"}
                </div>
            </div>
        );
    }
}

export default App;

