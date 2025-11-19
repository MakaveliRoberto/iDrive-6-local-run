#!/bin/bash

# Monitor git push progress

echo "=========================================="
echo "📊 Git Push Progress Monitor"
echo "=========================================="
echo ""

# Check if push is running
if pgrep -f "git.*push" >/dev/null; then
    echo "✅ Git push is RUNNING"
    echo ""
    PID=$(pgrep -f "git.*push" | head -1)
    echo "Process ID: $PID"
    echo "Runtime: $(ps -p $PID -o etime= 2>/dev/null | xargs)"
    echo "CPU: $(ps -p $PID -o %cpu= 2>/dev/null | xargs)%"
    echo "Memory: $(ps -p $PID -o %mem= 2>/dev/null | xargs)%"
    echo ""
else
    echo "⚠️  No git push process found"
    echo ""
    echo "Possible reasons:"
    echo "  • Push completed"
    echo "  • Push failed"
    echo "  • Push hasn't started yet"
    echo ""
    echo "Check status:"
    echo "  git status"
    echo "  git log origin/main..HEAD  # See unpushed commits"
    echo ""
fi

# Check network activity
echo "Network Activity:"
echo "-----------------"
if command -v lsof >/dev/null 2>&1; then
    NETWORK=$(lsof -i -P 2>/dev/null | grep -E "git|ssh|github" | head -5)
    if [ -n "$NETWORK" ]; then
        echo "$NETWORK"
    else
        echo "No active git/ssh connections"
    fi
else
    echo "lsof not available"
fi

echo ""
echo "Repository Size:"
echo "----------------"
if [ -d ".git" ]; then
    echo "Local repository: $(du -sh .git 2>/dev/null | awk '{print $1}')"
    echo "Total project: $(du -sh . 2>/dev/null | awk '{print $1}')"
fi

echo ""
echo "Unpushed Commits:"
echo "-----------------"
UNPUSHED=$(git log origin/main..HEAD --oneline 2>/dev/null | wc -l)
if [ "$UNPUSHED" -gt 0 ]; then
    echo "  $UNPUSHED commits waiting to push"
    git log origin/main..HEAD --oneline 2>/dev/null | head -5
else
    echo "  ✅ All commits pushed (or no remote tracking)"
fi

echo ""
echo "=========================================="
echo ""
echo "💡 Tips:"
echo "  • Large repos (15GB) can take 30-60+ minutes"
echo "  • Check GitHub website to see if files appear"
echo "  • If push fails, you can resume with same command"
echo "  • Use 'git push --verbose' for detailed output"
echo ""

