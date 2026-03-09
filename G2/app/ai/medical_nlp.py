"""
Medical NLP Module

Extracts medical entities from transcriptions and generates structured reports.
Currently uses rule-based extraction for development.
In production, integrate with medical NLP models (spaCy, BioBERT, GPT-4, etc.)
"""

from typing import Dict, List, Optional
import re
import logging

logger = logging.getLogger(__name__)


def generate_structured_report(
    transcription: str,
    patient_context: Optional[Dict] = None
) -> Dict:
    """
    Generate structured medical report from transcription.
    
    Extracts medical entities and organizes into SOAP format.
    
    Args:
        transcription: Raw transcribed text from doctor
        patient_context: Optional patient context including:
            - chronic_conditions: List of chronic diseases
            - current_medications: List of current medications
            - age: Patient age
            - allergies: Known allergies
            
    Returns:
        dict: Structured report with keys:
            - symptoms: List[str]
            - diagnosis: str
            - medications: List[dict] with name, dosage, frequency
            - soap: dict with subjective, objective, assessment, plan
            - follow_up: str
            
    Production Integration Example:
        ```python
        import openai
        
        prompt = f'''
        Extract medical information from this doctor's notes:
        
        {transcription}
        
        Patient context: {patient_context}
        
        Return JSON with: symptoms, diagnosis, medications, SOAP notes, follow_up
        '''
        
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}]
        )
        return json.loads(response.choices[0].message.content)
        ```
    """
    if not transcription or not transcription.strip():
        raise ValueError("Transcription cannot be empty")
    
    logger.info(f"Processing transcription ({len(transcription)} chars)")
    
    patient_context = patient_context or {}
    
    # Extract components using rule-based parsing
    symptoms = _extract_symptoms(transcription)
    diagnosis = _extract_diagnosis(transcription)
    medications = _extract_medications(transcription)
    soap = _generate_soap_format(transcription, patient_context)
    follow_up = _extract_follow_up(transcription)
    
    report = {
        "symptoms": symptoms,
        "diagnosis": diagnosis,
        "medications": medications,
        "soap": soap,
        "follow_up": follow_up
    }
    
    logger.info(f"Report generated: {len(symptoms)} symptoms, {len(medications)} medications")
    return report


def _extract_symptoms(text: str) -> List[str]:
    """Extract symptoms from text using pattern matching."""
    symptoms = []
    
    # Pattern: "complaints of", "presents with", "reports", "complains of"
    complaint_patterns = [
        r"complaints? of (.+?)(?:\.|,|$)",
        r"presents with (.+?)(?:\.|,|$)",
        r"reports (.+?)(?:\.|,|$)",
        r"complains of (.+?)(?:\.|,|$)"
    ]
    
    for pattern in complaint_patterns:
        matches = re.finditer(pattern, text, re.IGNORECASE)
        for match in matches:
            symptom = match.group(1).strip()
            if symptom and len(symptom) < 200:  # Reasonable length
                symptoms.append(symptom)
    
    # Common symptom keywords
    symptom_keywords = [
        "headache", "fever", "cough", "pain", "nausea", "vomiting",
        "diarrhea", "fatigue", "dizziness", "shortness of breath",
        "chest pain", "abdominal pain", "back pain"
    ]
    
    for keyword in symptom_keywords:
        if keyword.lower() in text.lower() and keyword not in symptoms:
            symptoms.append(keyword)
    
    return symptoms[:10]  # Limit to top 10


def _extract_diagnosis(text: str) -> str:
    """Extract diagnosis from text."""
    # Pattern: "diagnosis:", "appears to be", "likely", "diagnosed with"
    diagnosis_patterns = [
        r"diagnosis[:\s]+(.+?)(?:\.|$)",
        r"appears to be (.+?)(?:\.|$)",
        r"likely (.+?)(?:\.|$)",
        r"diagnosed with (.+?)(?:\.|$)",
        r"impression[:\s]+(.+?)(?:\.|$)",
        r"assessment[:\s]+(.+?)(?:\.|$)"
    ]
    
    for pattern in diagnosis_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            diagnosis = match.group(1).strip()
            if diagnosis and len(diagnosis) < 500:
                return diagnosis
    
    return "Clinical assessment pending further investigation"


def _extract_medications(text: str) -> List[Dict[str, str]]:
    """Extract medications with dosage and frequency."""
    medications = []
    
    # Pattern: "prescribing X", "give X", "start X", "X mg"
    med_patterns = [
        r"prescribing (.+?)(?:\.|$)",
        r"prescribed (.+?)(?:\.|$)",
        r"give (.+?)(?:\.|$)",
        r"start (.+?)(?:\.|$)",
        r"(\w+)\s+(\d+\s*mg)(?:\s+(.+?))?(?:\.|,|$)"
    ]
    
    for pattern in med_patterns:
        matches = re.finditer(pattern, text, re.IGNORECASE)
        for match in matches:
            if len(match.groups()) >= 3:
                # Detailed match with dosage
                name = match.group(1).strip()
                dosage = match.group(2).strip()
                frequency = match.group(3).strip() if match.group(3) else "as directed"
            else:
                # Simple match
                full_text = match.group(1).strip()
                # Try to parse dosage
                dosage_match = re.search(r"(\d+\s*mg)", full_text, re.IGNORECASE)
                if dosage_match:
                    dosage = dosage_match.group(1)
                    name = full_text.replace(dosage, "").strip()
                    # Try to extract frequency
                    freq_match = re.search(
                        r"(once|twice|three times|four times|daily|bid|tid|qid)",
                        full_text,
                        re.IGNORECASE
                    )
                    frequency = freq_match.group(1) if freq_match else "as directed"
                else:
                    name = full_text
                    dosage = "as prescribed"
                    frequency = "as directed"
            
            if name and len(name) < 100:
                medications.append({
                    "name": name,
                    "dosage": dosage,
                    "frequency": frequency
                })
    
    return medications[:10]  # Limit to 10 medications


def _generate_soap_format(text: str, context: Dict) -> Dict[str, str]:
    """Generate SOAP format notes."""
    # Split text into sections
    lines = [line.strip() for line in text.split('\n') if line.strip()]
    
    subjective = []
    objective = []
    assessment = []
    plan = []
    
    current_section = "subjective"  # Default to subjective
    
    # Keywords to detect sections
    subjective_keywords = ["complain", "report", "states", "denies", "patient"]
    objective_keywords = ["examination", "vital", "blood pressure", "heart rate", "temperature"]
    assessment_keywords = ["appears", "likely", "diagnosis", "impression", "based on"]
    plan_keywords = ["prescrib", "recommend", "advise", "follow-up", "return"]
    
    for line in lines:
        line_lower = line.lower()
        
        # Detect section based on keywords
        if any(kw in line_lower for kw in objective_keywords):
            current_section = "objective"
        elif any(kw in line_lower for kw in assessment_keywords):
            current_section = "assessment"
        elif any(kw in line_lower for kw in plan_keywords):
            current_section = "plan"
        
        # Add to appropriate section
        if current_section == "subjective":
            subjective.append(line)
        elif current_section == "objective":
            objective.append(line)
        elif current_section == "assessment":
            assessment.append(line)
        elif current_section == "plan":
            plan.append(line)
    
    # Add patient context to subjective if available
    if context.get("chronic_conditions"):
        chronic = ", ".join(context["chronic_conditions"])
        subjective.insert(0, f"Patient has known chronic conditions: {chronic}")
    
    return {
        "subjective": " ".join(subjective) if subjective else "Patient presents with above complaints.",
        "objective": " ".join(objective) if objective else "Physical examination findings noted above.",
        "assessment": " ".join(assessment) if assessment else "Clinical assessment as described.",
        "plan": " ".join(plan) if plan else "Treatment plan outlined above."
    }


def _extract_follow_up(text: str) -> str:
    """Extract follow-up instructions."""
    # Pattern: "follow-up", "return", "come back", "see me"
    followup_patterns = [
        r"follow[- ]up (.+?)(?:\.|$)",
        r"return (.+?)(?:\.|$)",
        r"come back (.+?)(?:\.|$)",
        r"see me (.+?)(?:\.|$)",
        r"schedule (.+?)(?:\.|$)"
    ]
    
    for pattern in followup_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            follow_up = match.group(1).strip()
            if follow_up:
                return f"Follow-up {follow_up}"
    
    # Default follow-up
    if "week" in text.lower():
        return "Follow-up in one week"
    elif "month" in text.lower():
        return "Follow-up in one month"
    
    return "Follow-up as needed or if symptoms worsen"


def extract_entities(text: str) -> Dict[str, List[str]]:
    """
    Extract medical entities from text.
    
    Simplified entity extraction for development.
    In production, use medical NER models.
    
    Args:
        text: Medical text
        
    Returns:
        dict: Entities by type (symptoms, conditions, medications, procedures)
    """
    return {
        "symptoms": _extract_symptoms(text),
        "medications": [med["name"] for med in _extract_medications(text)],
        "diagnosis": [_extract_diagnosis(text)]
    }
