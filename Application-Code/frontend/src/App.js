import React from "react";
import Tasks from "./Tasks";
import { Paper, TextField, Checkbox, Button } from "@material-ui/core";
import "./App.css";

class App extends Tasks {
    render() {
        const { tasks, currentTask } = this.state;
        return (
            <div className="App">
                <Paper elevation={3} className="container">
                    <div className="heading">My TO-DO List</div>
                    <form
                        onSubmit={this.handleSubmit}
                        className="flex"
                        style={{ margin: "15px auto" }}
                    >
                        <TextField
                            variant="outlined"
                            size="small"
                            style={{ width: "80%" }}
                            value={currentTask}
                            required={true}
                            onChange={this.handleChange}
                            placeholder="Add New TO-DO"
                        />
                        <Button
                            style={{ height: "40px" }}
                            color="primary"
                            variant="outlined"
                            type="submit"
                        >
                            Add
                        </Button>
                    </form>
                    <div>
                        {tasks.map((task) => (
                            <Paper key={task._id} className="flex task_container">
                                <Checkbox
                                    checked={task.completed}
                                    onClick={() => this.handleUpdate(task._id)}
                                    color="primary"
                                />
                                <div className={task.completed ? "task line_through" : "task"}>
                                    {task.task}
                                </div>
                                <Button
                                    onClick={() => this.handleDelete(task._id)}
                                    color="secondary"
                                >
                                    delete
                                </Button>
                            </Paper>
                        ))}
                    </div>
                </Paper>
            </div>
        );
    }
}

export default App;

// Webhook test 
