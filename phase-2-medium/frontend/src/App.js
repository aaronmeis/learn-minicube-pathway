import React, { useState, useCallback } from "react";
import "./App.css";

const API_BASE = "/api";

function App() {
  const [taskType, setTaskType] = useState("math");
  const [mathExpr, setMathExpr] = useState("");
  const [textValue, setTextValue] = useState("");
  const [textOp, setTextOp] = useState("reverse");
  const [results, setResults] = useState([]);
  const [status, setStatus] = useState("");

  const submitTask = useCallback(async () => {
    let payload;
    if (taskType === "math") {
      if (!mathExpr.trim()) return;
      payload = { type: "math", expr: mathExpr.trim() };
    } else {
      if (!textValue.trim()) return;
      payload = { type: "text", operation: textOp, value: textValue.trim() };
    }

    setStatus("Submitting...");
    try {
      const res = await fetch(`${API_BASE}/task`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      const data = await res.json();
      if (res.ok) {
        setStatus(`Queued: ${JSON.stringify(payload)}`);
      } else {
        setStatus(`Error: ${data.error}`);
      }
    } catch (err) {
      setStatus(`Network error: ${err.message}`);
    }
  }, [taskType, mathExpr, textValue, textOp]);

  const fetchResults = useCallback(async () => {
    setStatus("Fetching results...");
    try {
      const res = await fetch(`${API_BASE}/results`);
      const data = await res.json();
      if (res.ok && data.results.length > 0) {
        setResults((prev) => [...data.results, ...prev]);
        setStatus(`Fetched ${data.results.length} result(s)`);
      } else if (res.ok) {
        setStatus("No new results in queue");
      } else {
        setStatus(`Error: ${data.error}`);
      }
    } catch (err) {
      setStatus(`Network error: ${err.message}`);
    }
  }, []);

  return (
    <div className="app">
      <header>
        <h1>Task System</h1>
        <span className="badge">Phase 2</span>
      </header>

      <section className="card">
        <h2>Submit a Task</h2>

        <div className="type-toggle">
          <button
            className={taskType === "math" ? "active" : ""}
            onClick={() => setTaskType("math")}
          >
            Math
          </button>
          <button
            className={taskType === "text" ? "active" : ""}
            onClick={() => setTaskType("text")}
          >
            Text
          </button>
        </div>

        {taskType === "math" ? (
          <div className="field">
            <label>Expression</label>
            <input
              type="text"
              placeholder="e.g. factorial(10), sqrt(144), 2**16"
              value={mathExpr}
              onChange={(e) => setMathExpr(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && submitTask()}
            />
          </div>
        ) : (
          <>
            <div className="field">
              <label>Operation</label>
              <select value={textOp} onChange={(e) => setTextOp(e.target.value)}>
                <option value="reverse">reverse</option>
                <option value="upper">upper</option>
                <option value="lower">lower</option>
                <option value="length">length</option>
              </select>
            </div>
            <div className="field">
              <label>Value</label>
              <input
                type="text"
                placeholder="e.g. hello world"
                value={textValue}
                onChange={(e) => setTextValue(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && submitTask()}
              />
            </div>
          </>
        )}

        <button className="btn-primary" onClick={submitTask}>
          Submit Task
        </button>
      </section>

      <section className="card">
        <div className="results-header">
          <h2>Results</h2>
          <button className="btn-secondary" onClick={fetchResults}>
            Fetch Results
          </button>
        </div>

        {status && <p className="status">{status}</p>}

        {results.length === 0 ? (
          <p className="empty">No results yet. Submit a task then fetch results.</p>
        ) : (
          <ul className="results-list">
            {results.map((r, i) => (
              <li key={i}>{r}</li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}

export default App;
