# story_en — English narrative source-of-truth (single source for main.tex)

> Genre: applied / system paper in (bio)medical informatics, IMRaD. Goal: submittable, clear, logically coherent.
> Integrity: every number is an **author-supplied placeholder**; mark `illustrative`; never claim as measured in Abstract/Conclusion.

## Working title
A Metadata-Augmented Retrieval-to-SQL Generation and Execution-Feedback Verification Framework for Hospital Statistical Queries

## One-sentence thesis
For real hospital statistical querying, placing an LLM inside a controlled loop of domain-metadata constraint, SQL sub-structure decomposition, and four-layer execution-feedback verification yields **engineering-usable, criterion-traceable** SQL, where naive prompt-to-SQL is unsafe.

## Section spine (claim → evidence status)
1. **Introduction** — pain: manual SQL is slow, schema sprawls across source systems, statistical *criteria* (口径) drift; naive LLM-to-SQL hallucinates fields/criteria/joins. Contributions (4). [evidence: qualitative, real]
2. **Related Work** — Text-to-SQL (Seq2SQL/Spider/RAT-SQL/PICARD/DIN-SQL), RAG, LLM-in-healthcare, schema linking. Position: ours is *applied/engineering* not SOTA-on-benchmark. [evidence: citations, real]
3. **Method/Framework** —
   - 3.1 Metadata knowledge base (4 entry types: schema, metric-criterion, historical-SQL, exception-rule).
   - 3.2 Table/field recall + criterion mapping; recall score Score(c)=α·key+β·sem+γ·hist.
   - 3.3 SQL sub-structure generation (SELECT/FROM-JOIN/WHERE/GROUP BY/ORDER BY).
   - 3.4 Four-layer verification (syntax/field/criterion/result) + error-attribution feedback loop. [evidence: design, real]
4. **Experimental Setup** — 30 de-identified hospital tasks (8 monthly / 6 dept-ward / 6 complication / 5 multi-table / 5 criterion-ambiguity); 4 case archetypes; settings A/B/C/D; metrics (executable rate, key-field consistency, condition-recognition accuracy, result consistency [sampled], avg manual corrections, end-to-end latency); annotation protocol. [design real; numbers PLACEHOLDER]
5. **Results** — monotonic A→D improvement tables (Table main + Table efficiency + 5-class error taxonomy). [ALL numbers PLACEHOLDER/illustrative — author fills]
6. **Discussion** — why each lever helps; lessons learned; criterion-traceability as the clinical value. Generalization = conjecture only.
7. **Limitations** — single-site, single-database, N=30, builder-judged metrics, LLM-version dependence, latency cost.
8. **Conclusion** — feasibility demonstrated; future work (auto join-path recommendation, criterion auto-reconciliation, dynamic KB, human-in-the-loop learning). [no hard numbers]
9. **Ethics & data** — de-identification + IRB/governance statement; no real patient data in examples.

## Linchpins (claims must not exceed evidence)
- (a) single-site / N=30 / builder-judged → frame as feasibility/case study; generalization → Discussion conjecture.
- (b) A/B/C/D = internal ablation, NOT external-system comparison → never "outperforms prior methods".
- (c) human-judged metrics + sampled result-consistency → disclose protocol & sampling.
- (d) results depend on specific LLM+prompt+retrieval → report config; not model-agnostic.
- (e) hospital data → de-identification + IRB statement mandatory.
- (f) latency increase is a real trade-off → report honestly (reliability > single-shot speed).

## Patent alignment note
Self prior art: patent AJ2534335 (LLM + **RL** NL-to-structured-SQL generation/optimization). RED LINE: this paper uses RAG + execution feedback, **no RL** — do not import unimplemented RL claims. Cite patent as authors' prior disclosure; state this paper's increment (domain-grounded evaluation, four-layer verification, error taxonomy).
