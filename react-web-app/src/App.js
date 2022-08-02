import React from "react";
import ResponseForm from "./components/ResponseForm";
import PageNotFound from "./components/PageNotFound";
import {
  Routes,
  Route
} from 'react-router-dom';

function App() {
  return (    
    <div className="App">
      <Routes>
        <Route path="/:id" element={<ResponseForm />} />
        <Route path="*" element={<PageNotFound />} />
      </Routes>      
    </div>
  );
}

export default App;
