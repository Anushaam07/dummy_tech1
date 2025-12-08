# 📊 How to Use the Presentation Slides

## You Have 2 Files:

1. **PRESENTATION_SLIDES.md** - Actual slides (60+ slides)
2. **COMPLETE_DEMO_PRESENTATION.md** - Speaker notes & script

---

## 📝 Option 1: Use Marp (Recommended)

### Install Marp:
```bash
npm install -g @marp-team/marp-cli
```

### Convert to PDF:
```bash
cd /home/sigmoid/Documents/dummy_tech1/dummy
marp PRESENTATION_SLIDES.md --pdf
```

### Convert to PowerPoint:
```bash
marp PRESENTATION_SLIDES.md --pptx
```

### Present Directly:
```bash
marp PRESENTATION_SLIDES.md --preview
```

---

## 🎨 Option 2: Copy to Google Slides / PowerPoint

1. Open PRESENTATION_SLIDES.md
2. Copy each section (between `---`)
3. Paste into new slide in Google Slides
4. Add your company branding/colors

---

## 🌐 Option 3: Use reveal.js (HTML Slides)

### Create reveal.js presentation:
```bash
# Install reveal-md
npm install -g reveal-md

# Present
reveal-md PRESENTATION_SLIDES.md
```

Opens in browser at `http://localhost:1948`

---

## 📊 What's in the Slides

### Total: 60+ slides covering:

**Part 1: Hook (Slides 1-7)**
- Real-world disasters
- Common patterns
- Our challenge

**Part 2: Solution (Slides 8-12)**
- Promptfoo overview
- Architecture
- Defense layers

**Part 3: Demos (Slides 13-40)**
- Red team testing
- Guardrails in action
- Model comparison
- Continuous improvement

**Part 4: Business Value (Slides 41-50)**
- ROI calculation
- Before/after comparison
- Cost analysis

**Part 5: Results (Slides 51-56)**
- What we achieved
- Next steps
- Call to action

**Part 6: Q&A (Slides 57-60)**
- Common questions
- Contact info

**Backup Slides (Slides 61-68)**
- Technical details
- Code examples
- Metrics

---

## 🎯 Recommended Usage

### For 45-minute presentation:
1. Show slides **1-56** (main content)
2. Use backup slides **61-68** for Q&A
3. Refer to **COMPLETE_DEMO_PRESENTATION.md** for what to say

### For 30-minute presentation:
1. Skip backup slides
2. Combine some demo slides
3. Focus on key metrics

### For 15-minute executive summary:
1. Slides 1-7 (Hook)
2. Slides 8-12 (Solution)
3. Slides 41-50 (Business value)
4. Slides 51-56 (Results)

---

## 🎨 Customization Tips

### Add Your Branding:
```markdown
---
marp: true
theme: default
backgroundColor: #YOUR_COLOR
---
```

### Add Company Logo:
```markdown
![bg right:30%](path/to/logo.png)
```

### Change Colors:
Edit the frontmatter at the top of PRESENTATION_SLIDES.md

---

## 📱 Export Formats

### Marp can export to:
- ✅ PDF (for distribution)
- ✅ PowerPoint (for editing)
- ✅ HTML (for web)
- ✅ PNG images (for social media)

### Examples:
```bash
# PDF
marp PRESENTATION_SLIDES.md --pdf -o presentation.pdf

# PowerPoint
marp PRESENTATION_SLIDES.md --pptx -o presentation.pptx

# HTML
marp PRESENTATION_SLIDES.md --html -o presentation.html

# Images (one per slide)
marp PRESENTATION_SLIDES.md --images png
```

---

## 🎬 Presentation Mode

### Using Marp CLI:
```bash
marp PRESENTATION_SLIDES.md --preview
```

### Using reveal-md:
```bash
reveal-md PRESENTATION_SLIDES.md
```

### Keyboard Shortcuts:
- `→` Next slide
- `←` Previous slide
- `f` Fullscreen
- `s` Speaker notes (if added)
- `o` Overview mode

---

## 📝 Speaker Notes

Use **COMPLETE_DEMO_PRESENTATION.md** alongside slides:

1. Open slides in presentation mode
2. Open COMPLETE_DEMO_PRESENTATION.md in another window
3. Reference script for what to say on each slide

---

## ✅ Quick Start

### Fastest way to present:

```bash
# 1. Install Marp
npm install -g @marp-team/marp-cli

# 2. Present
marp PRESENTATION_SLIDES.md --preview

# 3. Export to PDF for sharing
marp PRESENTATION_SLIDES.md --pdf -o RAG_Security_Presentation.pdf
```

---

## 🎯 What Each Slide Shows

### Slide Format:
```markdown
---
# Title

Content here
- Bullet points
- Tables
- Code blocks

---
```

### Every `---` creates a new slide

---

## 📊 Sample Slides Preview

### Slide 1: Title
- Opens with strong hook
- Sets expectations

### Slides 2-7: Real-World Disasters
- Samsung leak
- Air Canada lawsuit
- Microsoft errors
- Common patterns

### Slides 8-12: Solution
- Promptfoo introduction
- Architecture diagram
- Three layers of defense

### Slides 13-40: Live Demos
- Red team results
- Guardrails blocking
- Model comparison
- Progress over time

### Slides 41-50: ROI
- Cost savings
- Security improvement
- Competitive analysis

### Slides 51-56: Wrap-up
- Achievements
- Next steps
- Call to action

---

## 🎤 Tips for Presenting

1. **Practice with slides 3 times**
2. **Run all demos beforehand**
3. **Have backup screenshots** in case live demo fails
4. **Use presenter notes** from COMPLETE_DEMO_PRESENTATION.md
5. **Time yourself** - aim for 40 mins, leave 5 for Q&A

---

## ✅ You're Ready!

You now have:
- ✅ 60+ professional slides
- ✅ Complete speaker script
- ✅ Multiple export formats
- ✅ Demo commands
- ✅ Q&A preparation

**Just practice and present!** 🚀
