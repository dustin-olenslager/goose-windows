import React, { useEffect, useState } from 'react';
import { Minus, Square, X, Maximize2 } from 'lucide-react';

interface WindowsTitleBarProps {
  title?: string;
}

export const WindowsTitleBar: React.FC<WindowsTitleBarProps> = ({ title = 'Goose' }) => {
  const [isMaximized, setIsMaximized] = useState(false);

  useEffect(() => {
    // Get initial maximized state
    window.electron.isWindowMaximized().then(setIsMaximized);

    // Listen for maximize state changes
    window.electron.onWindowMaximizedChange((maximized) => {
      setIsMaximized(maximized);
    });
  }, []);

  const handleMinimize = () => {
    window.electron.minimizeWindow();
  };

  const handleMaximize = () => {
    window.electron.maximizeWindow();
  };

  const handleClose = () => {
    window.electron.closeWindow();
  };

  return (
    <div className="windows-titlebar">
      <div className="windows-titlebar-drag">
        <span className="windows-titlebar-title">{title}</span>
      </div>
      <div className="windows-titlebar-controls">
        <button
          className="windows-titlebar-button windows-titlebar-minimize"
          onClick={handleMinimize}
          aria-label="Minimize"
        >
          <Minus size={16} strokeWidth={1} />
        </button>
        <button
          className="windows-titlebar-button windows-titlebar-maximize"
          onClick={handleMaximize}
          aria-label={isMaximized ? "Restore" : "Maximize"}
        >
          {isMaximized ? (
            <Maximize2 size={14} strokeWidth={1.5} />
          ) : (
            <Square size={12} strokeWidth={1.5} />
          )}
        </button>
        <button
          className="windows-titlebar-button windows-titlebar-close"
          onClick={handleClose}
          aria-label="Close"
        >
          <X size={16} strokeWidth={1.5} />
        </button>
      </div>
    </div>
  );
};

export default WindowsTitleBar;
